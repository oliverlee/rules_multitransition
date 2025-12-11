#include <cstddef>
#include <stdio.h>

auto main() -> int {
#ifdef __MACH__
  printf("__MACH__ = %d\n", __MACH__);
#endif
#ifdef __arm__
  printf("__arm__ = %d\n", __arm__);
#endif
#ifdef __ARM_ARCH
  printf("__ARM_ARCH = %d\n", __ARM_ARCH);
#endif
  printf("sizeof(std::size_t) = %u\n", sizeof(std::size_t));
  return 0;
}
