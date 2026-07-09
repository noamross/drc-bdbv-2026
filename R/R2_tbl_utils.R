# DuckDB connection pre-configured for R2 access
R2_duckdb_con <- function(bucket = "grant-witness-files", cache = TRUE) {
  con <- DBI::dbConnect(duckdb::duckdb(), ":memory:")
  key_id <- Sys.getenv("AWS_ACCESS_KEY_ID")
  secret <- Sys.getenv("AWS_SECRET_ACCESS_KEY")
  endpoint <- sub("^https?://", "", Sys.getenv("AWS_ENDPOINT_URL"))
  region <- Sys.getenv("AWS_REGION", unset = "auto")

  # Create a temporary CA cert file for DuckDB to use with httpfs
  ca_cert_file <- tempfile(fileext = ".pem")
  certs <- openssl::ca_bundle()
  pem_text <- paste(sapply(certs, openssl::write_pem), collapse = "")
  writeLines(pem_text, ca_cert_file)

  DBI::dbExecute(
    con,
    glue::glue(
      "
    INSTALL httpfs;
    LOAD httpfs;
    SET ca_cert_file = '{ca_cert_file}';
    CREATE OR REPLACE SECRET r2 (
      TYPE S3,
      KEY_ID '{key_id}',
      SECRET '{secret}',
      ENDPOINT '{endpoint}',
      REGION '{region}',
      URL_STYLE 'path'
    );
  "
    )
  )

  # Set up duckdb to cache its HTTP requests automatically
  cache_loaded <- FALSE
  if (isTRUE(cache)) {
    cache_dir <- tools::R_user_dir("grantwitness", "cache")
    dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
    cache_loaded <- tryCatch(
      {
        DBI::dbExecute(
          con,
          "INSTALL cache_httpfs FROM community; LOAD cache_httpfs;"
        )
        safe_cache_dir <- gsub("'", "''", cache_dir)
        DBI::dbExecute(
          con,
          sprintf("SET cache_httpfs_cache_directory = '%s'", safe_cache_dir)
        )
        TRUE
      },
      error = function(e) {
        cli::cli_warn(
          c(
            "Could not enable on-disk HTTP cache ({.pkg cache_httpfs}).",
            i = "Proceeding without disk cache.",
            x = conditionMessage(e)
          )
        )
        FALSE
      }
    )
  }

  con
}

# Lazy tbl over hive-partitioned parquet files in R2.
# `path` is a glob relative to the bucket root, e.g.
#   "nsf_awards/snapshot_date=*/data-*.parquet"
#   "reporter/snapshot_date=*/data-*.parquet"
R2_hive_tbl <- function(path, bucket = "grant-witness-files") {
  con <- R2_duckdb_con(bucket)
  DBI::dbExecute(
    con,
    glue::glue(
      "
    CREATE VIEW hive_tbl AS
    SELECT * FROM read_parquet(
      's3://{bucket}/{path}',
      hive_partitioning = true,
      union_by_name = true  -- allows for different columns in different snapshots, filling in NULLs as needed
    );
  "
    )
  )
  tbl <- dplyr::tbl(con, "hive_tbl")

  tbl
}
