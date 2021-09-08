include: "views/order_items.view"
explore:  order_items_base{
  from: order_items
}

view: order_items_ndt {
  derived_table: {
    explore_source: order_items_base {
      column: count {}
    }
  }
  dimension: count {
    type: number
  }
}

explore: order_items_ndt {
}
