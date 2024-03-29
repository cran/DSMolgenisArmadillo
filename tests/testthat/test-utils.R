test_that(".handle_last_command_error throws error message", {
  ok <- list(status_code = 200)
  get <- mock(ok)
  content <- mock(list(status = "FAILED", message = "Error"))
  setClass("connection", slots = list(handle = "character",
                                      token = "character"))
  connection <- new("connection", handle = "test", token = "token")

  expect_error(
    with_mock(
      .handle_last_command_error(connection),
      "httr::GET" = get,
      "httr::content" = content
    ), "Error"
  )
  expect_args(get, 1, handle = connection@handle, path = "/lastcommand",
              config = httr::add_headers(c("Authorization" =
                                             paste0("Bearer ",
                                                    connection@token))))
  expect_args(content, 1, ok)
})

test_that(".handle_last_command_error only works if status is FAILED", {
  setClass("connection", slots = list(handle = "character",
                                      token = "character"))
  connection <- new("connection", handle = "test", token = "token")
  ok <- list(status_code = 200)
  get <- mock(ok)
  content <- mock(list(status = "COMPLETED"))

  with_mock(
    .handle_last_command_error(connection),
    "httr::GET" = get,
    "httr::content" = content
  )

  expect_args(get, 1, handle = connection@handle, path = "/lastcommand",
              config = httr::add_headers(c("Authorization" =
                                             paste0("Bearer ",
                                                    connection@token))))
})

test_that(".handle_request_error handles 401", {
  expect_error(
    .handle_request_error(list(status_code = 401)),
    "Unauthorized"
  )
})

test_that(".handle_request_error handles 400", {
  response <- list(status_code = 400)
  httr_content <- mock(list(message = "Error"))
  with_mock(
    expect_error(
      .handle_request_error(response),
      "Bad request: Error"
    ),
    "httr::content" = httr_content
  )
})

test_that(".handle_request_error handles 500", {
  response <- list(status_code = 500)
  httr_content <- mock(list(message = "Error"))
  with_mock(
    expect_error(
      .handle_request_error(response),
      "Internal server error: Error"
    ),
    "httr::content" = httr_content
  )
})

test_that(".unlist_character_list handles empty list", {
  expect_equal(.unlist_character_list(list()), character())
})

test_that(".unlist_character_list unnests list", {
  input <- list(foo = list(a = "a", b = list(c = "d")))
  expect_equal(
    .unlist_character_list(input),
    c("foo.a" = "a", "foo.b.c" = "d")
  )
})

test_that(".deparse deparses vectors", {
  skip("I still don't get the .deparse arguments")
})

test_that(".retry_until_last_result handles 404 by retrieving lastcommand", {
  not_found <- list(status_code = 404)
  ok <- list(status_code = 200)
  command <- list(status = "FAILED", message = "Error")
  httr_retry <- mock(not_found)
  httr_get <- mock(ok)
  httr_content <- mock(command)

  expect_error(
    with_mock(
      .retry_until_last_result(connection),
      "httr::GET" = httr_get,
      "httr::content" = httr_content,
      "httr::RETRY" = httr_retry
    ), "Execution failed: Error"
  )

  expect_args(httr_get, 1, handle = connection@handle, path = "/lastcommand",
              config = httr::add_headers(c("Authorization" =
                                             paste0("Bearer ",
                                                    connection@token))))
  expect_args(httr_content, 1, ok)
})
