// Sleep
function sleep(ms)
{
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Animate fade
async function fadeIn(element)
{
  await sleep(1);
  element.style.opacity = '1';
}

async function fadeOut(element)
{
  var fadeTime = getComputedStyle(element).transitionDuration;
  var time = parseFloat(fadeTime.substring(0, fadeTime.length - 1));
  element.style.opacity = '0';
  await sleep(time * 1000);
  element.style.display = 'none';
}
