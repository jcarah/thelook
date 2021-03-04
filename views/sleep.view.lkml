view: sleep {
 derived_table: {
   sql: select sleep(20) as sleep;;
  persist_for: "0 seconds"
 }
  dimension: sleep {}
}



explore: sleep {
  persist_for: "0 seconds"
}
