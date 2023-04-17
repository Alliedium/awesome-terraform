variable "object_with_nulls" {
  type = any
}
locals {
  removed = merge({
    for k, v in var.object_with_nulls : k => v if v != null
  },
  {
   vm = {
    for k, v in var.object_with_nulls.vm : k => v if v != null
    }
  })
}

output "removed" {
  value = local.removed
}
