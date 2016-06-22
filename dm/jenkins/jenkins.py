# Copyright 2016 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
import yaml
import base64

"""Creates a Jenkins environment
"""


def GenerateConfig(context):
    """Generate configuration."""
    password = context.properties['password']
    zone = context.properties["zone"]
    cluster_name = context.env['deployment'] + '-' + 'gke-cluster'
    type_name = cluster_name + '-type'
    cluster_type = context.env['project'] + '/' + type_name
    v1_prefix = '/api/v1/namespaces/{namespace}/'
    extensions_prefix = '/apis/extensions/v1beta1/namespaces/{namespace}/'

    jenkins_home_image_source = "https://storage.googleapis.com/solutions-public-assets/jenkins-cd/jenkins-home.tar.gz"
    image_name = 'jenkins-home-image'
    jenkins_home_image = {'name': image_name,
                          'type': 'compute.v1.image',
                          'properties': {
                              'name': image_name,
                              'rawDisk': {
                                  'source': jenkins_home_image_source
                              }
                          }}
    jenkins_home = {'name': 'jenkins-home',
                    'type': 'compute.v1.disk',
                    'properties': {
                        'sourceImage': 'global/images/' + image_name,
                        'zone': zone
                    },
                    'metadata': {'dependsOn': ['jenkins-home-image']}

    }
    manifests = {'deployments': ['jenkins.yaml'],
                 'services': ['ui_service.yaml'],
                 'ingresses': ['ingress.yaml']}

    namespace = {'name': 'jenkins-namespace',
                 'type': '{0}:{1}{2}'.format(cluster_type, '/api/v1/', 'namespaces'),
                 'properties': {'apiVersion': 'v1',
                                'kind': 'Namespace',
                                'metadata': {'name': 'jenkins'}
                                },
                 'metadata': {'dependsOn': [cluster_name, type_name, 'jenkins-home-image']}
                 }
    options = "--argumentsRealm.passwd.jenkins={0} --argumentsRealm.roles.jenkins=admin"
    options_hash = base64.b64encode(options.format(password))
    secret = {'name': 'jenkins-secret',
              'type': '{0}:{1}{2}'.format(cluster_type, v1_prefix, 'secrets'),
              'properties': {'apiVersion': 'v1',
                             'kind': 'Secret',
                             'metadata': {'name': 'jenkins'},
                             'type': 'Opaque',
                             'namespace': 'jenkins',
                             'data': {
                                'options': options_hash
                              }
                             },
              'metadata': {'dependsOn': [namespace['name']]}
              }

    resources = [namespace, jenkins_home_image, jenkins_home, secret]
    for resource_type, filenames in manifests.iteritems():
        for path in filenames:
            type = '{0}:{1}{2}'.format(cluster_type, v1_prefix, resource_type)
            if resource_type in ['deployments', 'ingresses']:
                type = '{0}:{1}{2}'.format(cluster_type + '-extensions', extensions_prefix, resource_type)
            name = '{0}_{1}'.format(context.env['name'], path)
            resource = {'name': name,
                        'type': type,
                        'properties': yaml.safe_load(context.imports[path]),
                        'metadata': {'dependsOn': [namespace['name'], 'jenkins-home']}
                        }
            resource['properties']['namespace'] = 'jenkins'
            resources.append(resource)

    firewall_rule = {'name': 'k8s-ingress-fw-rule',
                     'type': 'compute.v1.firewall',
                     'properties': {
                        'name': image_name,
                        'sourceRanges': ["130.211.0.0/22"],
                        'allowed': [{'IPProtocol': 'TCP', 'ports': ['30001']}]
                      }
                     }
    resources.append(firewall_rule)
    # Resources to return.
    return {'resources': resources}
