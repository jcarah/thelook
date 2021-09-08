project_name: "thelook"

# # Use local_dependency: To enable referencing of another project
# # on this instance with include: statements
#
# local_dependency: {
#   project: "name_of_other_project"
# }

constant: connection_name {
  value: "thelookmysql"
  export: override_optional
}
