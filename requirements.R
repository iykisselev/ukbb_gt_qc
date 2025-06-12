# Install packages if not already installed
required_packages <- c("logging", "igraph", "dplyr")
new_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) install.packages(new_packages, repos="https://cloud.r-project.org") 