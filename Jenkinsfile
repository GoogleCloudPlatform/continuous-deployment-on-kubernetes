node {
  def appName = 'jenkins-gke'
  checkout scm

  stage 'Build image'
  sh("./tests/e2e.sh")
}