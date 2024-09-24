int responsiveCrossAxisCount(double width) {
  if (width > 1200) {
    return 4;
  } else if (width > 800) {
    return 3;
  } else if (width > 600) {
    return 2;
  } else {
    return 1;
  }
}
