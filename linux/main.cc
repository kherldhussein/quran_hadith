#include "my_application.h"

#include <clocale>
#include <cstdlib>

int main(int argc, char** argv) {
  // Force numeric locale to "C" so audio libraries relying on decimal parsing
  // work consistently regardless of the user's environment.
  setenv("LC_NUMERIC", "C", /*overwrite=*/0);
  setlocale(LC_NUMERIC, "C");

  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
