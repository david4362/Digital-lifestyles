# 00_constants.R — Digital lifestyles paper
# Single source of truth: paths, survey-item mapping, category groupings.

# --- Paths -------------------------------------------------------------------

# Konsumtionskollen project (data + reusable helpers). Override with env var
# in the TRE: Sys.setenv(DIGITAL_KK_DIR = "/safe/data/.../Konsumtionskollen")
KK_DIR <- Sys.getenv("DIGITAL_KK_DIR", unset = file.path("..", "Konsumtionskollen"))
KK_DATA_FILE <- file.path(KK_DIR, "default_filter.RData")

CACHE_DIR  <- "cache"
CACHE_FILE <- file.path(CACHE_DIR, "digital_cache.RData")
OUTPUT_DIR <- "output"
dir.create(CACHE_DIR,  showWarnings = FALSE)
dir.create(OUTPUT_DIR, showWarnings = FALSE)

# --- Survey-item mapping (PROVISIONAL — codebook pending, see notes/) --------

# Candidate blocks for the digital lifestyle battery.
Q15_ITEMS   <- paste0("q15_", 1:12)            # minutes/day time-use battery
Q11_ITEMS   <- paste0("q11_", 1:7)             # 1-6 Likert frequencies
Q11B_ITEMS  <- paste0("q11b_", 1:8)            # 1-6 Likert frequencies
DIGITAL_CANDIDATES <- c(Q15_ITEMS, Q11_ITEMS, Q11B_ITEMS, "q12", "q12b", "q13", "q14")

# The device-assisted screen-time anchor: item E4 in the ENDLINE survey.
# Question (Swedish): "Hur mycket tid spenderar du framför mobilen? ... öppna
# inställningarna för 'Skärmtid' (iOS) eller 'Digitalt välmående' (Android)
# ... notera den genomsnittliga dagliga skärmtiden i timmar och minuter för
# föregående vecka (mån-sön)." => AVERAGE DAILY screen time (hours:minutes),
# device-assisted, previous week. NOT in the local mock RData (baseline survey
# only); available in the TRE endline data. Expected object/column names TBD —
# the loader accepts an `endline` data frame with columns aid + E4-derived
# minutes (see 00_load_data.R).
SCREEN_TIME_ITEM <- "E4"   # endline survey; minutes/day after parsing h:mm

# Out-of-home leisure frequency (mechanism variable). Unconfirmed.
LEISURE_ITEM <- NA_character_

# --- Category groupings for the decomposition (DRAFT) ------------------------
# Leaf categories from Konsumtionskollen's categories.csv / broad-category.csv.
# Justify and finalize before pre-registered decomposition runs.

CATS_TRANSPORT <- c("fuel", "car_maint", "car_rent", "vehicles", "public_trans",
                    "bus", "taxi", "transport_other", "escooter", "aviation",
                    "ferry", "train_bus")

CATS_ECOMMERCE_INTENSIVE <- c("clothing", "electronics", "books", "toys",
                              "sports", "shopping_other", "home_garden_other")

CATS_DIGITAL_SERVICES <- c("internet_tele")     # + streaming/subscriptions if separable

CATS_PLACEBO <- c("rent", "insurance")          # no plausible digital channel

# --- Analysis parameters ------------------------------------------------------

WINSOR_P <- 0.99          # P99 winsorization, as in Konsumtionskollen
MIN_SCREEN_MIN <- 0       # plausibility window for screen-time minutes/day
MAX_SCREEN_MIN <- 16 * 60 # > 16 h/day flagged implausible

# Swedish benchmark bands for daily mobile screen time (minutes/day).
# HEURISTIC, pending verification against Internetstiftelsen
# "Svenskarna och internet" (latest edition). Do not cite these as-is.
SE_SCREEN_BENCH <- data.frame(
  age_group = c("18-29", "30-44", "45-64", "65+"),
  lo_min    = c(180, 120,  90,  45),
  hi_min    = c(420, 330, 240, 180)
)
