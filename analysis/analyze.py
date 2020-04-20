#!/usr/bin/env python3
import os
import sys
import yara

class PenZshAnalyze:
    def __init__(self,files):
        self.files    = files
        self.rulesdir = os.path.dirname(os.path.realpath(__file__)) + '/yara'
        self.rules    = yara.compile(filepaths={
                'HTB' : self.rulesdir + 'HTB'
            })

    def analyze(self):
        pass

    def postprocess(self):
        self.postprocess_output()
        self.postprocess_notes()
        self.postprocess_todos()

    def postprocess_output(self):
        # Print all of the analyzation output to the screen
        pass

    def postprocess_notes(self):
        # Add appropriate notes to penzsh notes, if they don't exist already
        pass

    def postprocess_todos(self):
        # Add appropriate todos to penzsh todos, if they don't exist already
        pass

def main():
    pza = PenZshAnalyze(files=sys.argv[1:])
    pza.analyze()
    pza.postprocess()

if __name__ == '__main__':
    main()
