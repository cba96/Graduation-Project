#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <iostream>

#include "cuda_runtime.h"
#include "device_launch_parameters.h"


#define MAX 200
#define LEN 10000
#define SAM 100

#define TILE_WIDTH 32

using namespace std;

__global__ void Initialize(char* _A, int _nLength) {
	int i = blockIdx.x *blockDim.x + threadIdx.x;
	int j = blockIdx.y *blockDim.y + threadIdx.y;
	bool finding = true;
	int RndAsc = 0;
	while (finding) {
		RndAsc = (clock() + i + j) % ((123 - 65) + 1) + 65;
		if (RndAsc == 123) RndAsc = 32;
		if ((RndAsc <= 90) || (RndAsc >= 97)) finding = false;
	}
	_A[i*_nLength + j] = char(RndAsc);
}

void Evaluation(char* _A, char* _Input, int _nLength, int* _nSum) {
	for (int i = 0; i < MAX; i++) {
		for (int j = 0; j < _nLength; j++) {
			if (_A[i * _nLength + j] == _Input[j])
				_nSum[i]++;
		}
	}
}

int Selection(char* _A, char* _ABackUp, int _nLength, int* _nSum) {
	int *nSamList = new int[SAM];
	for (int i = 0; i < SAM; i++) {
		int max = 0;
		int temp = 0;
		for (int j = 0; j < MAX; j++) {
			if (max < _nSum[j]) {
				max = _nSum[j];
				temp = j;
			}
		}
		nSamList[i] = temp;
		_nSum[temp] = 0;
	}
	for (int i = 0; i < SAM; i++) {
		for (int j = 0; j < _nLength; j++) {
			_ABackUp[i*_nLength + j] = _A[nSamList[i] * _nLength + j];
		}
	}

	return nSamList[0];
}

__global__ void Replace(char* _A, char* _ABackUp, int _nLength) {
	int i = blockIdx.x *blockDim.x + threadIdx.x;
	if (i < MAX) {
		int nCut = (clock() + blockDim.x * threadIdx.x) % _nLength;
		int F = (clock() - blockDim.x + threadIdx.x) % SAM;
		int M = (clock() + blockDim.x - threadIdx.x) % SAM;
		for (int j = 0; j < nCut; j++) {
			_A[i * _nLength + j] = _ABackUp[F*_nLength + j];
		}
		for (int j = nCut; j < _nLength; j++) {
			_A[i * _nLength + j] = _ABackUp[M*_nLength + j];
		}
	}
}

__global__ void Mutation(char* _A, int _nLength) {
	int i = blockIdx.x *blockDim.x + threadIdx.x;
	int j = blockIdx.y *blockDim.y + threadIdx.y;
	if (i < MAX && j < _nLength) {
		if ((clock() + blockIdx.x - blockDim.y * threadIdx.x) % 1000 == 0) {
			bool finding = true;
			int RndAsc = 0;
			while (finding) {
				RndAsc = (clock() + blockIdx.y - blockDim.x * threadIdx.y) % ((123 - 65) + 1) + 65;
				if (RndAsc == 123) RndAsc = 32;
				if ((RndAsc <= 90) || (RndAsc >= 97)) finding = false;
			}
			_A[i * _nLength + j] = char(RndAsc);
		}
	}
}

void main() {
	char *A = new char[MAX*LEN];
	char *ABackUp = new char[MAX*LEN];

	char *dev_A, *dev_ABackUp;

	cudaError_t cudaStatus = cudaSetDevice(0);
	cudaStatus = cudaMalloc((void**)&dev_A, MAX * LEN * sizeof(bool));
	cudaStatus = cudaMalloc((void**)&dev_ABackUp, MAX * LEN * sizeof(bool));

	dim3 dimGrid((MAX - 1) / TILE_WIDTH + 1, (LEN - 1) / TILE_WIDTH + 1);
	dim3 dimBlock(TILE_WIDTH, TILE_WIDTH);
	dim3 dimGrid2((MAX - 1) / TILE_WIDTH + 1);
	dim3 dimBlock2(TILE_WIDTH);

	srand(time(NULL));
	//memory allocation

	char Input[MAX] = { 0 };
	cout << "Input Sentece :";

	fgets(Input, sizeof(Input), stdin);
	//gene initialize

	int nLength = strlen(Input) - 1;
	clock_t st = clock();
	Initialize << <dimGrid, dimBlock >> > (dev_A, nLength);
	cudaDeviceSynchronize();

	int stack = 0;
	cudaStatus = cudaMemcpy(A, dev_A, MAX*LEN * sizeof(bool), cudaMemcpyDeviceToHost);
	while (true) {
		int *nSum = new int[MAX] {0};
		//gene evaluation
		Evaluation(A, Input, nLength, nSum);
		int *nSumCopy = new int[MAX] {0};
		memcpy(nSumCopy, nSum, MAX * sizeof(int));
		//gene selection
		int nMaxGen = Selection(A, ABackUp, nLength, nSumCopy);
		stack++;

		if (stack % 1000 == 0) {
			cout << endl << stack << "번째\t" << endl;
			for (int i = 0; i < nLength; i++)
				cout << A[nMaxGen * nLength + i];
			cout << endl;
		}

		if (nSum[nMaxGen] >= nLength) {
			cout << endl << stack << "번째\t" << ((float)(clock() - st)) / 1000 << "초  \t" << endl << endl;
			cout << "최종 결과" << endl;
			for (int i = 0; i < nLength; i++)
				cout << A[nMaxGen * nLength + i];
			cout << endl;
			break;
		}

		//gene replacement
		cudaStatus = cudaMemcpy(dev_A, A, MAX*LEN * sizeof(bool), cudaMemcpyHostToDevice);
		cudaStatus = cudaMemcpy(dev_ABackUp, ABackUp, MAX*LEN * sizeof(bool), cudaMemcpyHostToDevice);
		Replace << <dimGrid2, dimBlock2 >> >(dev_A, dev_ABackUp, nLength);
		cudaDeviceSynchronize();

		//gene mutation
		Mutation << <dimGrid, dimBlock >> >(dev_A, nLength);
		cudaDeviceSynchronize();

		cudaStatus = cudaMemcpy(A, dev_A, MAX*LEN * sizeof(bool), cudaMemcpyDeviceToHost);
		cudaStatus = cudaMemcpy(ABackUp, dev_ABackUp, MAX*LEN * sizeof(bool), cudaMemcpyDeviceToHost);
	}
}
