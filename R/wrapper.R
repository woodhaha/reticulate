
#' Scaffold R wrappers for Python functions
#' 
#' @param python_function Fully qualfied name of Python function or class 
#'   constructor (e.g. `tf$layers$average_pooling1d`)
#' @param r_prefix Prefix to add to generated R function name
#' @param r_function Name of R function to generate (defaults to name of Python 
#'   function if not specified)
#'   
#' @note The generated wrapper will often require additional editing (e.g. to
#'   convert Python list literals in the docs to R lists, to massage R numeric
#'   values to Python integers via `as.integer` where required, etc.) so is
#'   really intended as an starting point for an R wrapper rather than a wrapper
#'   that can be used without modification.
#'   
#' @export
py_function_wrapper <- function(python_function, r_prefix = NULL, r_function = NULL) {
  
  # get the docs
  docs <- py_function_docs(python_function)
  
  # generate wrapper w/ roxygen
  con <- textConnection("wrapper", "w")
  
  # title/description
  write(sprintf("#' %s\n#' ", docs$description), file = con)
  details <- gsub("\n", "\n#' ", docs$details, fixed = TRUE)
  write(sprintf("#' %s\n#' ", details), file = con)
  
  # parameters
  for (param in names(docs$parameters))
    write(sprintf("#' @param %s %s", param, docs$parameters[[param]]), file = con)
  
  # returns
  if (isTRUE(nzchar(docs$returns))) {
    write("#' ", file = con)
    write(sprintf("#' @return %s", docs$returns), file = con)
  }
  
  # sections
  for (section in names(docs$sections)) {
    section_text <- docs$sections[[section]]
    section_text <- gsub("\n", "\n#' ", section_text, fixed = TRUE)
    write("#' ", file = con)
    write(sprintf("#' @section %s:\n#' %s", section, section_text), file = con)
  }
  
  # export
  write("#' ", file = con)
  write("#' @export", file = con)
  
  # signature
  if (is.null(r_function)) {
    r_function <- docs$name
    if (!is.null(r_prefix))
      r_function <- paste(r_prefix, r_function, sep = "_")
  }
  signature <- sub(paste0(r_function, "\\("), paste(r_function, "<- function("), docs$signature)
  write(paste(signature, "{"), file = con)
  
  # delegation
  write(paste0("  ", python_function, "("), file = con)
  params <- names(docs$parameters)
  if (length(params) > 0) {
    for (i in 1:length(params)) {
      suffix <- if (i < length(params))
        ","
      else
        "\n  )"
      write(paste0("    ", params[[i]], " = ", params[[i]], suffix), file = con)
    }
  } else {
    write(")", file = con)
  }
  
  # end function
  write("}", file = con)
  
  # close the connection 
  close(con)
  
  # return the wrapper with a special class so we can write a print method
  class(wrapper) <- c("py_wrapper", "character")
  wrapper
}

#' @rdname py_function_wrapper
#' @export
py_function_docs <- function(python_function) {
  
  # eval so that python loads
  eval(parse(text = python_function))
  
  # get components
  components <- strsplit(python_function, "\\$")[[1]]
  topic <- components[[length(components)]]
  source <- paste(components[1:(length(components)-1)], collapse = "$")
  
  # get function docs
  function_docs <- help_handler(type = "completion", topic, source)
  
  # get parameter docs
  parameter_docs <- help_handler(type = "parameter", NULL, python_function)
  
  # create a named list with parameters
  parameters <- parameter_docs$arg_descriptions
  names(parameters) <- parameter_docs$args
  
  # create a new list with all doc info
  list(name = function_docs$title,
       qualified_name = python_function,
       description = function_docs$description,
       details = function_docs$details,
       signature = function_docs$signature,
       parameters = parameters,
       sections = function_docs$sections,
       returns = function_docs$returns)
}


#' @export
print.py_wrapper <- function(x, ...) {
  cat(x, sep = "\n")
}







