// fails unless built with `compilation_mode = "opt"`, which defines `NDEBUG`
auto main() -> int {
#ifdef NDEBUG
  return 0;
#else
  return 1;
#endif
}
