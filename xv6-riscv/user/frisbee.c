#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int pass_no = 0;
int pass_round = 0;
int thread_num;
int thrower;

lock_t lock;

void *play(void *arg)
{
	int tid = *(uint64*)arg;
	int pass_num = pass_round;
	int i;
	for(i=0;i<pass_num;i++)
	{
		if(thrower!=tid)
		{
			lock_acquire(&lock);
			pass_no++;
			printf("Pass number %d : ",pass_no);
			printf("Thread %d is passing the token to Thread %d\n",thrower,tid);
			thrower = tid;
			lock_release(&lock);
			sleep(20);
		}
		tid = (tid+1)%thread_num;
	}
	printf("Simulation of Frisbee game has finished, %d rounds were played in total\n",pass_round);
	exit(0);
}

int main(int argc, char *argv[])
{
	lock_init(&lock);
	thread_num = atoi(argv[1]);
	pass_round = atoi(argv[2]);
	
	int i;
	uint64 arg = 0;
	for(i=0;i<thread_num;i++)
	{
		arg = i+1;
		thread_create(play((void*)&arg),(void*)&arg); 
		sleep(10);
	}
	sleep(40);
	exit(0);
}