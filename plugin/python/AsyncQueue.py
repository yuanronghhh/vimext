from queue import Queue
from threading import Lock, Condition
import logging
import utils


class AsyncQueue(Queue):
    def __init__(self):
        super().__init__()
        self.cond = Condition()

    def enqueue(self, item):
        self.cond.acquire()

        utils.log("%s", ("enqueue"))

        self.put_nowait(item)
        self.cond.notify_all()

        self.cond.release()

    def dequeue(self):
        self.cond.acquire()

        while True:
            self.cond.wait()

            nitem = self.get_nowait()
            if nitem:
                break

        self.task_done()
        self.cond.release()

        return nitem
