/*
 * Copyright (c) 2015, the Dart project authors.
 *
 * Licensed under the Eclipse Public License v1.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 *
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License.
 */
package org.dartlang.vm.service;

import com.google.common.base.Charsets;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;

/**
 * Echo the content of a stream to {@link System.out} with the given prefix.
 */
public class SampleOutPrinter {
    private class LinesReaderThread extends Thread {
        public LinesReaderThread() {
            setName("SampleOutPrinter.LinesReaderThread - " + prefix);
            setDaemon(true);
        }

    @Override
    public void run() {
      while (true) {
        String line;
        try {
          line = reader.readLine();
        } catch (IOException e) {
          System.out.println("Exception reading sample stream");
          e.printStackTrace();
          return;
        }
        // check for EOF
        if (line == null) {
          return;
        }
        synchronized (currentLineLock) {
          currentLine = line;
          currentLineLock.notifyAll();
        }
        System.out.println("[" + prefix + "] " + line);
      }
    }
  }

    private String currentLine;

    private final Object currentLineLock = new Object();

    private final String prefix;
    private final BufferedReader reader;

    public SampleOutPrinter(String prefix, InputStream stream) {
        this.prefix = prefix;
        this.reader = new BufferedReader(new InputStreamReader(stream, Charsets.UTF_8));
        new LinesReaderThread().start();
    }

    public void assertEmpty() {
        synchronized (currentLineLock) {
            if (currentLine != null) {
                throw new RuntimeException("Did not expect " + prefix + ": \"" + currentLine + "\"");
            }
        }
    }

    public void assertLastLine(String text) {
        synchronized (currentLineLock) {
            if (text == null) {
                if (currentLine != null) {
                    throw new RuntimeException("Did not expect " + prefix + ": \"" + currentLine + "\"");
                }
            } else {
                if (currentLine == null || !currentLine.contains(text)) {
                    throw new RuntimeException("Expected current line to contain text\n"
                            + "\nexpected: [" + text + "]"
                            + "\nactual: [" + currentLine + "]");
                }
            }
        }
    }
}
