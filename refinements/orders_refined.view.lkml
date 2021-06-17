include: "/views/orders.view"
view: +orders {
  dimension: new_dimesion {
    sql: 1 ;;
  }
  dimension: id {
    description: "this a description to the existing id"
    sql: ${TABLE}.id +1 ;;
  }
}
