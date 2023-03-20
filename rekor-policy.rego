package signature
 
default allow = true

allow = false {
  input.predicate.Data.type == "Checkout"
  result := contains(input.predicate.Data.stage_properties.scm.committed_by, "")
  result != true
}

allow = false {
  input.predicate.Data.type == "dockerbuild"
  input.predicate.Data.stage_properties.application_image != "APPROVED"
}

allow = false {
  input.predicate.Data.type == "dockerpublish"
  result := contains(input.predicate.Data.stage_properties.url, "")
  result != true
}

allow = false {
  input.predicate.Data.type == "helmpublish"
  result_1 := contains(input.predicate.Data.stage_properties.url, "")
  result_2 := contains(input.predicate.Data.stage_properties.url, "")
  result := any([result_1,result_2]) 
  result != true
}

allow = false {
 input.predicate.Data.type == "sonarquality"
 input.predicate.Data.stage_properties.enabled != true
}
