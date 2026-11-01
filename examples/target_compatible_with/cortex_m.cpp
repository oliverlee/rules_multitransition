// fails unless built for a Cortex-M (M-profile) target
auto main() -> int {
#if defined(__ARM_ARCH_PROFILE) && __ARM_ARCH_PROFILE == 'M'
  return 0;
#else
  return 1;
#endif
}
