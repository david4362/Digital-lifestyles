# English figure labels: complete words, no raw variable names.
# Sourced by figure scripts: source("05_labels.R")

modellab <- c(M0_bivariate = "Bivariate", M1_sex_age = "+ Sex & age",
  M2_income_educ = "+ Incomes & education", M3_household = "+ Household/children",
  M4_density = "+ Log density", M5_city = "+ Major city (full)")

grouplab <- c(total = "Total", transport = "Transport", ecom = "E-commerce intensive",
  digital = "Digital services", rent = "Rent (housing tenure)",
  placebo_insurance = "Insurance (placebo)", vehicles = "Vehicles")

# Leaf stems (without top_ prefix / _co2e|_kr suffix) -> labels
stemlab <- c(fuel = "Fuel", car_maint = "Car maintenance", car_rent = "Car rental",
  public_trans = "Public transport", bus = "Bus", taxi = "Taxi", train_bus = "Train & bus",
  aviation = "Aviation", ferry = "Ferry", escooter = "E-scooter",
  transport_other = "Other transport", clothing = "Clothing", electronics = "Electronics",
  books = "Books", toys = "Toys", sports = "Sports", shopping_other = "Other shopping",
  home_garden_other = "Home & garden", internet_tele = "Internet & telecom",
  rent = "Rent", insurance = "Insurance", vehicles = "Vehicles", groceries = "Groceries",
  restaurant = "Restaurants", electricity = "Electricity", furniture = "Furniture")

cap1 <- function(s) paste0(toupper(substring(s, 1, 1)), substring(s, 2))

# Groups via lookup; leaves like top_fuel_co2e -> "Fuel (top 10)"
fulllab <- function(x) {
  out <- unname(grouplab[x])
  leaf <- is.na(out)
  stem <- sub("_co2e$|_kr$", "", sub("^top_", "", x[leaf]))
  top <- grepl("^top_", x[leaf])
  y <- unname(stemlab[stem])
  y[is.na(y)] <- cap1(gsub("_", " ", stem[is.na(y)]))
  out[leaf] <- ifelse(top, paste0(y, " (top 10)"), y)
  out
}
