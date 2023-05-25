#' Export WeeWX Data
#'
#' Export selected variables from a WeeWX database.
#'
#' @param db_path Path to the WeeWX database file.
#' @return A data frame with selected variables.
#' @importFrom RSQLite SQLite
#' @importFrom pool dbPool poolClose
#' @importFrom dplyr tbl collect select mutate
#' @importFrom lubridate as_datetime
#' @importFrom rlang .data
#' @importFrom magrittr %>%
#' @export
export_weewx <- function(db_path) {
  tryCatch(
    {
      pool <- pool::dbPool(
        drv = RSQLite::SQLite(),
        dbname = db_path
      )

      con <- pool::poolCheckout(pool)

      w <- dplyr::tbl(con, "archive") %>% dplyr::collect()

      pool::poolReturn(con)

      pool::poolClose(pool)

      vars_to_retrieve <- c("dateTime", "outTemp", "rain", "radiation")

      dplyr::select(w, !!!vars_to_retrieve) %>%
        dplyr::mutate(dateTime = lubridate::as_datetime(.data$dateTime))
    },
    error = function(e) {
      message("Error accessing the WeeWX database: ", e$message)
      NULL
    }
  )
}

#' Tidy WeeWX Variable Names
#'
#' Rename variables from WeeWX format to snake case.
#'
#' @param data A tibble containing the WeeWX data.
#' @return A tibble with variable names converted to snake case.
#' @importFrom dplyr rename_all
#' @export
tidy_weewx_names <- function(data) {
  new_names <- names(data) %>%
    stringr::str_replace_all("\\.", "_") %>%
    stringr::str_replace_all("([A-Z])", "_\\1") %>%
    stringr::str_replace_all("_+", "_") %>%
    stringr::str_to_lower()

  dplyr::rename_all(data, ~new_names)
}
