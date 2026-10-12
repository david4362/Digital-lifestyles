# English figure labels: complete words, no raw variable names.
# Sourced by figure scripts: source("05_labels.R")

modellab = c(M0_bivariate = "Bivariate", M1_sex_age = "+ Sex & age",
  M2_income_educ = "+ Incomes & education", M3_household = "+ Household/children",
  M4_density = "+ Log density", M5_city = "+ Major city (full)")

# Index-variant labels (42's second ladder, 59's variants table)
variantlab = c(
  main = "Revised index: excludes e-commerce & online selling (11 items)",
  nocalls = "Also minus calls (10 items)")

grouplab = c(total = "Total", transport = "Transport", ecom = "E-commerce intensive",
  digital = "Digital services", rent = "Rent (housing tenure)",
  placebo_insurance = "Insurance (placebo)", vehicles = "Vehicles")

# Leaf stems (without top_ prefix / _co2e|_kr suffix) -> labels
stemlab = c(fuel = "Fuel", car_maint = "Car maintenance", car_rent = "Car rental",
  public_trans = "Public transport", bus = "Bus", taxi = "Taxi", train_bus = "Train & bus",
  aviation = "Aviation", ferry = "Ferry", escooter = "E-scooter",
  transport_other = "Other transport", clothing = "Clothing", electronics = "Electronics",
  books = "Books", toys = "Toys", sports = "Sports", shopping_other = "Other shopping",
  home_garden_other = "Home & garden", internet_tele = "Internet & telecom",
  rent = "Rent", insurance = "Insurance", vehicles = "Vehicles", groceries = "Groceries",
  restaurant = "Restaurants", electricity = "Electricity", furniture = "Furniture")

cap1 = function(s) paste0(toupper(substring(s, 1, 1)), substring(s, 2))

# One human label per target name: the hypothesis groups via grouplab, the
# top-10 leaves via stemlab on the category stem (top_fuel_co2e ->
# "Fuel (top 10)"); a stem missing from stemlab falls back to the stem
# itself with spaces and a capital first letter.
fulllab = function(x) {
  unname(vapply(x, function(nm) {
    if (nm %in% names(grouplab)) return(grouplab[[nm]])
    top = startsWith(nm, "top_")
    stem = sub("_co2e$|_kr$", "", sub("^top_", "", nm))
    y = if (stem %in% names(stemlab)) stemlab[[stem]] else cap1(gsub("_", " ", stem))
    if (top) paste0(y, " (top 10)") else y
  }, character(1)))
}
