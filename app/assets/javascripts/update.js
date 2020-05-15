function updateMake(content) {
    document.getElementById("preview-make").innerHTML = content;
}

function updateModel(content) {
  document.getElementById("preview-model").innerHTML = content;
}

function updateYear(content) {
  document.getElementById("preview-year").innerHTML = content;
}

function updateFrequency(content) {
  if(content.includes("three_months")) {
    frequency = "Every 3 Months";
  }
  else {
    frequency = "Every 6 months";
  }
  document.getElementById("preview-frequency").innerHTML = frequency;
}

function updateQuality(content) {
  if(content.includes("good")) {
    quality = "Good";
  }
  else if(content.includes("better")) {
    quality = "Better";
  }
  else {
    quality = "Best";
  }
  document.getElementById("preview-quality").innerHTML = quality;
}