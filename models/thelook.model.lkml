connection: "thelookmysql"

# include all the views
include: "/views/**/*.view"

datagroup: thelook_default_datagroup {
  sql_trigger: select {{ 'now' | date: "%-m" }} ;;
  max_cache_age: "1 hour"
}

persist_with: thelook_default_datagroup
explore: events {
  access_filter: {
    field: users.email
    user_attribute: email
  }
  sql_always_where:
  {% if _user_attributes['sales_filtering'] == 'no' %}
    ${users.email} =  {{ _user_attributes['email'] }}
  {% else %}
    1=1
  {% endif %}

  ;;
  join: users {
    type: left_outer
    sql_on: ${events.user_id} = ${users.id} ;;
    relationship: many_to_one
  }
}

explore: flights {}



explore: inventory_items {
  join: products {
    type: left_outer
    sql_on: ${inventory_items.product_id} = ${products.id} ;;
    relationship: many_to_one
  }
}

# explore: order_items {
#   join: orders {
#     type: left_outer
#     sql_on: ${order_items.order_id} = ${orders.id} ;;
#     relationship: many_to_one
#   }

#   join: inventory_items {
#     type: left_outer
#     sql_on: ${order_items.inventory_item_id} = ${inventory_items.id} ;;
#     relationship: many_to_one
#   }

#   join: users {
#     type: left_outer
#     sql_on: ${orders.user_id} = ${users.id} ;;
#     relationship: many_to_one
#   }

#   join: products {
#     type: left_outer
#     sql_on: ${inventory_items.product_id} = ${products.id} ;;
#     relationship: many_to_one
#   }
# }

# explore: orders {
#   join: users {
#     type: left_outer
#     sql_on: ${orders.user_id} = ${users.id} ;;
#     relationship: many_to_one
#   }
# }

explore: products {}
