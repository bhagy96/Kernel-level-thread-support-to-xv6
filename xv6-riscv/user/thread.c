#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/fcntl.h"
#include "user/user.h"
#include "kernel/spinlock.h"

void *thread_create(void*(start_routine)(void*),void *arg)
{
	void *stack = malloc(2*4096U);
	if((uint64)stack%4096U)
	{
		stack = stack + (4096U - (uint64)stack%4096U);
	}
	int size = 8;
	int tid = clone(stack,size,start_routine,arg);
	if(tid<0)
	{
		printf("Clone failed\n",tid);
		return 0;
	}
	texit();
	return 0;
}

int lock_init(lock_t *lock)
{
	lock->flag = 0;
	return 0;
}
void lock_acquire(lock_t *lock)
{
	//lock->flag = 1;
	while (__sync_lock_test_and_set(&lock->flag, 1))
            ;
}

void lock_release(lock_t *lock){
	lock->flag = 0;
}
