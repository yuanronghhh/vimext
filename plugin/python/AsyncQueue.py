import threading
import logging

from queue import Queue
from threading import Lock, Condition


class AsyncQueue(Queue):
    def __init__(self):
        super().__init__()
        self.cond = Condition()

    def enqueue(self, item):
        self.cond.acquire()

        self.put_nowait(item)
        self.cond.notify()

        self.cond.release()

    def dequeue(self):
        self.cond.acquire()

        while True:
            self.cond.wait()

            nitem = self.get_nowait()
            if nitem:
                break

        self.cond.release()

        return nitem
