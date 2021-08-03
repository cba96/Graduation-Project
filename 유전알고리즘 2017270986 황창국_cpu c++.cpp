#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <iostream>

#define MAX 200
#define LEN 10000
#define SAM 100

using namespace std;

void Initialize(char* _A, int _nLength) {
	for (int i = 0; i < MAX; i++) {
		for (int j = 0; j < _nLength; j++) {
			bool finding = true;
			int RndAsc = 0;
			while (finding) {
				RndAsc = rand() % ((123 - 65) + 1) + 65;
				if (RndAsc == 123) RndAsc = 32;
				if ((RndAsc <= 90) || (RndAsc >= 97)) finding = false;
			}
			_A[i*_nLength + j] = char(RndAsc);
		}
	}
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

void Replace(char* _A, char* _ABackUp, int _nLength) {
	for (int i = 0; i < MAX; i++) {
		int nCut = rand() % _nLength;
		int F = rand() % SAM;
		int M = rand() % SAM;
		for (int j = 0; j < nCut; j++) {
			_A[i * _nLength + j] = _ABackUp[F*_nLength + j];
		}
		for (int j = nCut; j < _nLength; j++) {
			_A[i * _nLength + j] = _ABackUp[M*_nLength + j];
		}
	}
}

void Mutation(char* _A, int _nLength) {
	for (int i = 0; i < MAX; i++) {
		for (int j = 0; j < _nLength; j++) {
			if (rand() % 1000 == 0) {
				bool finding = true;
				int RndAsc = 0;
				while (finding) {
					RndAsc = rand() % ((123 - 65) + 1) + 65;
					if (RndAsc == 123) RndAsc = 32;
					if ((RndAsc <= 90) || (RndAsc >= 97)) finding = false;
				}
				_A[i * _nLength + j] = char(RndAsc);
			}
		}
	}
}

void main() {
	char *A = new char[MAX*LEN];
	char *ABackUp = new char[MAX*LEN];

	srand(time(NULL));

	//memory allocation
	char Input[LEN] = { 0 };
	cout << "Input Sentece :";

	fgets(Input, sizeof(Input), stdin);

	//gene initialization
	int nLength = strlen(Input) - 1;
	clock_t st = clock();
	Initialize(A, nLength);
	int stack = 0;

	while (true) {
		int *nSum = new int[MAX] {0};

		stack++;

		//gene evaluation
		Evaluation(A, Input, nLength, nSum);
		int *nSumCopy = new int[MAX] {0};
		memcpy(nSumCopy, nSum, MAX * sizeof(int));

		//gene selection
		int nMaxGen = Selection(A, ABackUp, nLength, nSumCopy);
		if (stack % 1000 == 0) {
			cout << endl << stack << "번째\t" << endl;
			for (int i = 0; i < nLength; i++)
				cout << A[nMaxGen * nLength + i];
			cout << endl;
		}


		if (nSum[nMaxGen] >= nLength ) {
			cout << endl << stack << "번째\t" << ((float)(clock() - st)) / 1000 << "초  \t" << endl << endl;
			cout << "최종 결과 " << endl;
			for (int i = 0; i < nLength; i++)
				cout << A[nMaxGen * nLength + i];
			cout << endl;
			break;
		}

		//gene replacement
		Replace(A, ABackUp, nLength);

		//gene mutation
		Mutation(A, nLength);
	}
}