view: event_attribute {
  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.ID ;;
  }

  dimension: event_id {
    type: number
    # hidden: true
    sql: ${TABLE}.EVENT_ID ;;
  }

  dimension: name {
    sql: ${TABLE}.NAME ;;

  }

  dimension: value {
    sql: ${TABLE}.VALUE ;;
    label: "{{ _view._name }}"
  }

  # Scheduler Delivery only -- needs to be plain text for scheduling
  dimension: schedule_plan_history_link {
    sql: case when ${TABLE}.name = 'scheduled_plan_id'
          then concat('https://looker.hubspotcentral.net/admin/scheduled_jobs?scheduled_plan_id=',${TABLE}.value)
         else null
         end;;
    html: {{value}} ;;
  }

  measure: count {
    type: count
    drill_fields: [id, name, event.id, event.name]
  }
}
