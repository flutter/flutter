function run(args_array = []) {

  let terminal = Application("Terminal.app");

  let directory = args_array[0];
  let command = args_array[1];
  let exitCode = args_array[2];

  let windowIds = [];
  for (let window of terminal.windows()) {
    windowIds.push(window.id());
  }

  terminal.open(directory);
  let newWindow = null;
  for (let window of terminal.windows()) {
    if (windowIds.includes(window.id()) === false) {
      newWindow = window;
      break;
    }
  }

  if (newWindow != null) {
    terminal.doScript(command, { in: newWindow });
    terminal.doScript(exitCode, { in: newWindow });
    delay(1);

    let tab = newWindow.tabs()[0];
    const checkFrequencyInSeconds = 0.5;
    const maxWaitInSeconds = 10 * 60; // 10 minutes
    const iterations = maxWaitInSeconds * (1 / checkFrequencyInSeconds);
    for (let i = 0; i < iterations; i++) {
      if (tab.busy() === false) {
        break;
      }
      delay(checkFrequencyInSeconds);
    }
    newWindow.close();
  } else {
    console.log("Failed to find window");
  }
}