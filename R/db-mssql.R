#' @export
`db_desc.Microsoft SQL Server` <- function(x) {
  info <- DBI::dbGetInfo(x)

  host <- if (info$servername == "") "localhost" else info$servername
  port <- if (info$port == "") "" else paste0(":", port)

  paste0(
    info$dbms.name, " ", info$db.version,
    "[", info$username, "@", host, port,
    "/", info$dbname , "]")

}

#' @export
`sql_select.Microsoft SQL Server`<- function(con, select, from, where = NULL,
                                             group_by = NULL, having = NULL,
                                             order_by = NULL,
                                             limit = NULL,
                                             distinct = FALSE,
                                             ...) {
  out <- vector("list", 7)
  names(out) <- c("select", "from", "where", "group_by",
                  "having", "order_by","limit")

  assert_that(is.character(select), length(select) > 0L)
  out$select <- build_sql(
    "SELECT ",

    if (distinct) sql("DISTINCT "),

    # MS SQL uses the TOP statement instead of LIMIT which is what SQL92 uses
    # TOP is expected after DISTINCT and not at the end of the query
    # e.g: SELECT TOP 100 * FROM my_table
    if (!is.null(limit) && !identical(limit, Inf)) {
      assert_that(is.numeric(limit), length(limit) == 1L, limit > 0)
      build_sql(" TOP ", as.integer(limit), " ")},

    escape(select, collapse = ", ", con = con)
  )
  assert_that(is.character(from), length(from) == 1L)
  out$from <- build_sql("FROM ", from, con = con)

  if (length(where) > 0L) {
    assert_that(is.character(where))
    where_paren <- escape(where, parens = TRUE, con = con)
    out$where <- build_sql("WHERE ", sql_vector(where_paren, collapse = " AND "))
  }

  if (length(group_by) > 0L) {
    assert_that(is.character(group_by))
    out$group_by <- build_sql(
      "GROUP BY ",
      escape(group_by, collapse = ", ", con = con)
    )
  }

  if (length(having) > 0L) {
    assert_that(is.character(having))
    out$having <- build_sql(
      "HAVING ",
      escape(having, collapse = ", ", con = con)
    )
  }

  if (length(order_by) > 0L) {
    assert_that(is.character(order_by))
    out$order_by <- build_sql(
      "ORDER BY ",
      escape(order_by, collapse = ", ", con = con)
    )
  }

  escape(unname(compact(out)), collapse = "\n", parens = FALSE, con = con)
}



#' @export
`sql_translate_env.Microsoft SQL Server` <- function(con) {
  sql_variant(
    scalar = sql_translator(.parent = base_scalar,
      as.numeric    = function(x) build_sql("CAST(", x, " AS NUMERIC)"),
      as.double     = function(x) build_sql("CAST(", x, " AS NUMERIC)"),
      as.integer    = function(x) build_sql("CAST(", x, " AS INT)"),
      as.logical    = function(x) build_sql("CAST(", x, " AS BOOLEAN)"),
      as.character  = function(x) build_sql("CAST(", x, " AS VARCHAR(MAX))"),
      as.Date       = function(x) build_sql("CAST(", x, " AS DATE)"),
      # MSSQL supports CONCAT_WS in the CTP version of 2016
      paste0        = sql_prefix("CONCAT")
    ),
    aggregate = sql_translator(.parent = base_agg,
      # MSSQL does not have function for: cor and cov
      n =          function() sql("COUNT(*)"),
      count =      function() sql("COUNT(*)"),
      n_distinct = function(x) build_sql("COUNT(DISTINCT ", x, ")"),
      sd =         sql_prefix("STDEV"),
      var =        sql_prefix("VAR")
    )
  )}



