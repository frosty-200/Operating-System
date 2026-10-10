#include<stdbool.h>
#include<stddef.h>
#include<stdint.h>
#include<unistd.h>
#include<string.h>
#include<assert.h>
#include<stdio.h>
#include<sys/mman.h>

#define HEAP_CAP 640000
#define HEAP_ALLOC_CAP 1024
#define HEAP_FREE_CAP 1024

typedef struct
{
	size_t size;
	void* start;
}Heap_chunk;

Heap_chunk freed_heap[HEAP_FREE_CAP]={0};
size_t free_mem_size = 0;

char heap[HEAP_CAP] = {0};
size_t heap_size = 0;
Heap_chunk heap_alloced[HEAP_ALLOC_CAP] = {0};
size_t heap_alloced_size = 0;

void* heap_allocator(size_t size)
{
	assert(heap_size + size < HEAP_CAP);

	void* result = heap_size + heap;
	heap_size += size;

	const Heap_chunk chunk={
		.size = size,
		.start = result,
	};
	assert(heap_alloced_size < HEAP_ALLOC_CAP);
	heap_alloced[heap_alloced_size++] = chunk;

	return result;

}

void dump_heap(void)
{
	for(size_t i = 0; i < heap_alloced_size; i++)
	{
		printf("  start: %p,   size %zu\n", heap_alloced[i].start, heap_alloced[i].size);
	}
}

void freed_sort(void)
{printf("inside the freed func\n");

	for(size_t i = 0; i < free_mem_size; i++)
	{
		printf(freed_heap[i].start);
		for(size_t j = 0; j < free_mem_size; j++)
		{	if(i == j) continue;
			if((char*)freed_heap[i].start + freed_heap[i].size == (char*)freed_heap[j].start)
			{
				printf("found the chunk to join up, sorting it boss\n");
				freed_heap[i].size += freed_heap[j].size;
				freed_heap[j] = freed_heap[--free_mem_size];
				i = 0;break;
			}
			else
			{
				printf("no adjacent memory to merge here, moving on\n");
			}
		}
	}
}


void heap_free(void* ptr)
{

	for(size_t i = 0; i < heap_alloced_size; i++)
	{
		if(heap_alloced[i].start == ptr)
		{
			freed_heap[free_mem_size++] = heap_alloced[i];
			memset(ptr, 0, heap_alloced[i].size);
			heap_alloced[i] = heap_alloced[--heap_alloced_size];
			return;
		}
	}

}

size_t check_size(size_t data)
{
	size_t alignment = 8;
	size_t sum = (data + alignment -1) & ~(alignment -1);
	if(sum <= alignment)
	{
		return alignment;
	}
	else
	{
		return(data + alignment - 1) & ~(alignment -1);
	}
}

void dump_freed()
{
	for(size_t i = 0; i < free_mem_size; i ++)
	{
		printf("the start: %p the size: %zu\n", freed_heap[i].start, freed_heap[i].size);
	}
}

int main()
{
	char data[512];
	printf("enter the data to input to heap\n");
	fgets(data, sizeof(data), stdin);
	size_t len = strlen(data);
	size_t sizing = check_size(len);
	char* newword = heap_allocator(sizing);
	strcpy(newword, data);

	printf("enter the data to input to heap\n");
	fgets(data, sizeof(data), stdin);
	size_t len2 = strlen(data);
	size_t sizing2 = check_size(len2);
	char* newdata = heap_allocator(sizing2);
	strcpy(newdata, data);

	printf("enter the data to input to heap\n");
	fgets(data, sizeof(data), stdin);
	size_t len3 = strlen(data);
	size_t sizing3 = check_size(len3);
	char* newdata2 = heap_allocator(sizing3);
	strcpy(newdata2, data);

	printf("enter the data to input to heap\n");
	fgets(data, sizeof(data), stdin);
	size_t len4 = strlen(data);
	size_t sizing4 = check_size(len4);
	char* newdata3 = heap_allocator(sizing4);
	strcpy(newdata3, data);

	dump_heap();
	printf("\n");

	printf("freeing: %p\n", newdata2);
	heap_free(newdata2);
	dump_heap();
	printf("free heap is this\n");
	dump_freed();
	printf("\n");

	printf("freeing: %p\n", newdata);
	heap_free(newdata);
	dump_heap();
	printf("the freed heap is this\n");
	dump_freed();
	printf("\n");

	printf("freeing: %p\n", newword);
	heap_free(newword);
	dump_heap();
	printf("\n");

	freed_sort();
	dump_freed();
	return 0;
}

