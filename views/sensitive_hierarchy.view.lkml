include: "/views/users.view"

# Build a summary table w/o PII
# This can live outside of looker

view: users_summarized {
  derived_table: {
    explore_source: users {
      column: count {}
      column: state {}
      column: gender {}
      column: country {}
      column: city {}
      column: age {}
    }
  }
  measure: count {
    type: sum
    sql: ${TABLE}.count  ;;
  }
  dimension: state {}
  dimension: gender {}
  dimension: country {}
  dimension: city {}
  dimension: age {
    type: number
  }
}

view: dynamic_users {
  sql_table_name:

  {% if _user_attributes["can_see_granular_data"] == "yes" %}
    public.users
  {% else %}
    ${users_summarized.SQL_TABLE_NAME}
  {% endif %}
  ;;
  measure: count {
    type: sum
    sql: ${TABLE}.count  ;;
  }
  dimension: state {}
  dimension: gender {}
  dimension: country {}
  dimension: city {}
  dimension: age {
    type: number
  }
}

explore: dynamic_users{

}
