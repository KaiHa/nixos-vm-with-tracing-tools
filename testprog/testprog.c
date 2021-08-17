#include <stdio.h>


void b(int limit) {
  int n = 0;
  for (int i=0; i<limit; i++) {
    n += i;
  }
}

void a(int a) {
  b(a*a);
}

int main(void) {
  a(3000);
  b(1500000);
}
