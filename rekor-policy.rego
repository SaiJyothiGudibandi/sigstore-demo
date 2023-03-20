package signature
 
default allow = true

allow = false {
  input.predicate.type == "checkout"
  result := contains(input.predicate.stage_properties.scm.application_ci.committed_by, "@gmail.com")
  result != true
}

allow = false {
  input.predicate.type == "dockerbuild"
  input.predicate.stage_properties.application_image != "APPROVED"
}

allow = false {
  input.predicate.type == "dockerpublish"
  result := contains(input.predicate.stage_properties.url, "us-central1-docker.pkg.dev/citric-nimbus-377218/docker-dev-local")
  result != true
}

allow = false {
  input.predicate.type == "helmpublish"
  result := contains(input.predicate.stage_properties.url, "oci://us-central1-docker.pkg.dev/citric-nimbus-377218/helm-dev-local/")
  result != true
}

allow = false {
  input.predicate.type == "sonarquality"
  input.predicate.stage_properties.enabled != "true"
}

allow = false {
  input.predicate.type == "blackduckquality"
  input.predicate.stage_properties.enabled != "true"
}

allow = false {
  input.predicate.environment == "verify"  
  input.predicate.type == "sonarquality"
  input.predicate.stage_properties.scan_status != "PASSED"
}

allow = false {  
   input.predicate.environment == "prod"                 
   input.predicate.type == "sonarquality"
   input.predicate.stage_properties.scan_status != "PASSED"
}
