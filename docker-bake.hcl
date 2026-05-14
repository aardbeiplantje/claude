group "default" {
  targets = ["release"]
}
group "release" {
  targets = ["containers"]
}
variable "DOCKER_REGISTRY" {
  default = "ghcr.io"
}
variable "DOCKER_REPOSITORY" {
  default = "ai"
}
variable "DOCKER_IMAGE_NAME" {
  default = "claude"
}
variable "DOCKER_TAG" {
  default = "latest"
}
variable "CLAUDE_CODE_VERSION" {
  default = "2.1.141"
}
target "containers" {
  pull = true
  name = "containers-${env}"
  matrix = {
    env = ["release"]
  }
  progress = ["plain", "tty"]
  tags = [
    "${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_NAME}:${DOCKER_TAG}",
  ]
  output = [
    "type=image,name=${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_NAME}:${DOCKER_TAG},push=true"
  ]
  cache-to = [
    "type=registry,ref=${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_NAME}:cache,mode=max"
  ]
  cache-from = [
    "type=registry,ref=${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_NAME}:cache",
    "type=registry,ref=${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_NAME}:${DOCKER_TAG}"
  ]
  target = "runtime"
  buildkit = true
  attest = [
    "type=provenance,mode=max",
    "type=sbom",
  ]
  context = "."
  dockerfile = "Dockerfile"
  networks = ["host"]
  platforms = [
    "linux/amd64"
  ]
  args = {
    CACHEBUST = "1"
    CLAUDE_CODE_VERSION = "${CLAUDE_CODE_VERSION}"
  }
}
