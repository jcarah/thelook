connection: "@{connection_name}"

# include all the views
include: "/views/**/*.view"
include: "/foo.explore"

datagroup: thelook_default_datagroup {
  sql_trigger: select {{ 'now' | date: "%-m" }} ;;
  max_cache_age: "1 hour"
}

# access_grant: can_see_events {
#   user_attribute: "country"
#   allowed_values: ["USA"]
# }

persist_with: thelook_default_datagroup
explore: events {
  # required_access_grants: [can_see_events]
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

explore: users {}
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

explore: orders {
  join: users {
    type: left_outer
    sql_on: ${orders.user_id} = ${users.id} ;;
    relationship: many_to_one
  }
  aggregate_table: rollup__created_date__users_age__users_city__users_gender {
    query: {
      dimensions: [created_date, users.age, users.city, users.gender]
      measures: [count]
    }

    materialization: {
      datagroup_trigger: thelook_default_datagroup
    }
  }
# Place in `thelook` model

    aggregate_table: rollup__created_month__users_age__users_city__users_gender {
      query: {
        dimensions: [created_month, users.age, users.city, users.gender]
        measures: [count]
      }

      materialization: {
        datagroup_trigger: thelook_default_datagroup
      }

  }

}


# Place in `thelook` model
explore: +orders {

}

explore: products {}
