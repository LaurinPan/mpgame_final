# Runs the five verification scripts in order, then the two that build on
# test 05: 05b, which writes its tables once both samples are annotated, and
# 05c, the model comparison. Each writes its table to 03_Verification/results/.
# Run from the main folder. 05, 05b and 05c need the recordings of
# 03_Verification/record_topics.R.
for (script in c("03_Verification/01_closed_forms.R", "03_Verification/02_reductions.R", "03_Verification/03_gali_table_6_1.R",
                 "03_Verification/04_visibility.R", "03_Verification/05_faithfulness.R", "03_Verification/05b_annotation.R", "03_Verification/05c_model_comparison.R")) {
  cat("\n==", script, "==\n")
  source(script)
}
