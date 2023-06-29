#include <iostream>
#include <vector>	
#include <bitset>
#include <charconv>
#include <string>	
#include <omp.h>
#include <execution>
#include <algorithm>				
#include <time.h>
#include <random>
#include <math.h>	

class GA_Class {
public:
	bool parent = false;
	std::string StringOfGa;
	uint64_t Fitness = 0;
};

typedef std::vector<GA_Class> GA_Vector;

static int GenerateRandomNumber(int min, int max) {
	std::random_device rd;
	std::mt19937 gen(rd());
	std::uniform_int_distribution<> dis(min, max);
	return dis(gen);
}

static float GenerateRandomFloat(float min, float max) {
	std::random_device rd;
	std::mt19937 gen(rd());
	std::uniform_real_distribution<float> dis(min, max);
	return dis(gen);
}

std::bitset<8> charToBits(char c) {
	return std::bitset<8>(c);
}

std::vector<bool> StringToBits(const std::string& str) {
	std::vector<bool> bits;
	bits.reserve(str.size() * 8);

	for (char c : str) {
		std::bitset<8> charBits = charToBits(c);
		for (size_t i = 0; i < 8; ++i) {
			bits.push_back(charBits[i]);
		}
	}

	return bits;
}

std::string BitToString(const std::vector<bool>& bits) {
	std::string result;
	result.reserve(bits.size() / 8 + 1); // pre-allocate memory for the string
	for (std::size_t i = 0; i < bits.size(); i += 8) {
		char byte = 0;
		for (std::size_t j = 0; j < 8 && i + j < bits.size(); j++) {
			byte |= static_cast<char>(bits[i + j]) << j;
		}
		result += byte;
	}
	return result;
}

namespace Genetic
{
	namespace General
	{
		static inline void InitPopulation(GA_Vector& population, GA_Vector& buffer, std::string& TargetWord, size_t SizeOfPopulation)
		{
			std::random_device rd;
			std::mt19937 gen(rd());
			std::uniform_int_distribution<> dis(32, 121);

			population.reserve(SizeOfPopulation);
			for (size_t Index = 0; Index < SizeOfPopulation; ++Index)
			{
				GA_Class citizen;
				citizen.Fitness = 0;
				citizen.StringOfGa.clear();
				citizen.StringOfGa.reserve(TargetWord.size());

				for (size_t Index_2 = 0; Index_2 < TargetWord.size(); ++Index_2)
				{
					citizen.StringOfGa += static_cast<char>(dis(gen));
				}
				population.emplace_back(std::move(citizen));
			}
			buffer.resize(SizeOfPopulation);
		}

		static void FitnessComputing(GA_Vector& population, std::string& TargetWord, size_t SizeOfPopulation)
		{
			#pragma omp parallel

			#pragma omp for
			for (ptrdiff_t Index = 0; Index < population.size(); ++Index)
			{
				//#pragma omp for
				for (ptrdiff_t Letter = 0; Letter < population[Index].StringOfGa.size(); ++Letter)
				{
					if (!(population[Index].StringOfGa[Letter] == TargetWord[Letter]))
					{
						population[Index].Fitness += 1 + 1;
					}
				}
			}
		}

		static inline void Crossover(GA_Vector& population, std::string& TargetWord)
		{
			const size_t SizeOfPopulation = population.size() & ~1; // Round down to nearest even number
			#pragma omp parallel
			#pragma omp for
			for (ptrdiff_t Index = 0; Index < SizeOfPopulation; Index += 2)
			{
				GA_Class& FirstMember = population[Index];
				GA_Class& SecondMember = population[Index + 1];
				FirstMember.parent = true;
				SecondMember.parent = true;

				const int length = GenerateRandomNumber(1, FirstMember.StringOfGa.length());
				std::string FirstPartOfFirstMember, SecondPartOfFirstMember;
				std::string FirstPartOfSecondMember, SecondPartOfSecondMember;

				FirstPartOfFirstMember.reserve(length);
				SecondPartOfFirstMember.reserve(FirstMember.StringOfGa.length() - length);

				FirstPartOfSecondMember.reserve(length);
				SecondPartOfSecondMember.reserve(SecondMember.StringOfGa.length() - length);

				for (size_t Index_2 = 0; Index_2 < length; ++Index_2)
				{
					FirstPartOfFirstMember += FirstMember.StringOfGa[Index_2];
					FirstPartOfSecondMember += SecondMember.StringOfGa[Index_2];
				}
				for (size_t Index_2 = length; Index_2 < FirstMember.StringOfGa.length(); ++Index_2)
				{
					SecondPartOfFirstMember += FirstMember.StringOfGa[Index_2];
					SecondPartOfSecondMember += SecondMember.StringOfGa[Index_2];
				}

				GA_Class FirstChild, SecondChild;

				FirstChild.StringOfGa.reserve(FirstMember.StringOfGa.length());
				SecondChild.StringOfGa.reserve(SecondMember.StringOfGa.length());

				FirstChild.StringOfGa = std::move(FirstPartOfFirstMember + SecondPartOfSecondMember);
				SecondChild.StringOfGa = std::move(FirstPartOfSecondMember + SecondPartOfFirstMember);

				population[Index] = std::move(FirstChild);
				population[Index + 1] = std::move(SecondChild);
			}
		}

		namespace Mutation
		{
			//auto GA_ELIT = 0.10f;

			static inline void Mutate(GA_Vector& Population, std::string& TargetWord)
			{
				float MutateChance = 0.80f; float ElitPopulation = 0.50f;
				int ElitSize = Population.size() * ElitPopulation;
				if (GenerateRandomFloat(0.01f, 1.00f) < MutateChance)
				{
					std::random_device rd;
					std::mt19937 gen(rd());
					std::uniform_int_distribution<> dis(32, 121);

					#pragma omp for
					for (ptrdiff_t Unit = 0; Unit <= ElitSize; ++Unit)
					{
						for (ptrdiff_t Letter = 0; Letter < Population[Unit].StringOfGa.size(); ++Letter)
						{
							char PrevisiousLetter = Population[Unit].StringOfGa[Letter];
							uint64_t PrevisiousFitness = Population[Unit].Fitness;

							Population[Unit].StringOfGa[Letter] = static_cast<char>(dis(gen));
							Population[Unit].Fitness = 0;

							for (ptrdiff_t Letter = 0; Letter < Population[Unit].StringOfGa.size(); ++Letter)
							{
								if (!(Population[Unit].StringOfGa[Letter] == TargetWord[Letter]))
								{
									Population[Unit].Fitness += 1 + 1;
								}
							}

							if (Population[Unit].Fitness > PrevisiousFitness || Population[Unit].Fitness == PrevisiousFitness)
							{
								Population[Unit].StringOfGa[Letter] = PrevisiousLetter;
							}
						}
						/*BitMutation
						std::vector<bool> BitsOfString = StringToBits(Population[Unit].StringOfGa);
						for (size_t Index = 0; Index < BitsOfString.size(); ++Index)
						{
							if (BitsOfString[Index] == false)
							{
								BitsOfString[Index] = true;
							}
							else
							{
								BitsOfString[Index] = false;
							}

							uint8_t PrevisiousFitness = Population[Unit].Fitness;

							Population[Unit].StringOfGa = BitToString(BitsOfString);
							Population[Unit].Fitness = 0;

							for (size_t Letter = 0; Letter < Population[Unit].StringOfGa[Letter]; ++Letter)
							{
								if (!(Population[Unit].StringOfGa[Letter] == TargetWord[Letter]))
								{
									Population[Unit].Fitness += 1 + 1;
								}
							}

							if (Population[Unit].Fitness > PrevisiousFitness)
							{
								if (BitsOfString[Index] == false)
								{
									BitsOfString[Index] = true;
								}
								else
								{
									BitsOfString[Index] = false;
								}
							}
						}
						*/
					}
				}
			}

			/*
			static inline void Mutate(GA_Class& Member, std::string& TargetWord)
			{
				int ipos = rand() % TargetWord.size();
				int delta = (rand() % 90) + 32;

				Member.StringOfGa[ipos] = ((Member.StringOfGa[ipos] + delta) % 122);
			}

			static void Elitism(GA_Vector &population, GA_Vector &buffer, int ElitSize)
			{
				for (int Index = 0; Index < ElitSize; ++Index)
				{
					buffer[Index].StringOfGa = population[Index].StringOfGa;
					buffer[Index].Fitness = population[Index].Fitness;
				}
			}

			static void Mate(GA_Vector& population, GA_Vector& buffer, std::string& TargetWord, size_t SizeOfPopulation)
			{
				int ElitSize = SizeOfPopulation * GA_ELIT;
				int spos = 0, i1 = 0, i2 = 0;

				Elitism(population, buffer, ElitSize);

				for (int ElitIndexer = ElitSize; ElitIndexer < SizeOfPopulation; ++ElitIndexer)
				{
					i1 = rand() % (SizeOfPopulation / 2);
					i2 = rand() % (SizeOfPopulation / 2);
					spos = rand() % TargetWord.size();

					buffer[ElitIndexer].StringOfGa = population[i1].StringOfGa.substr(0, spos) +
						population[i2].StringOfGa.substr(spos, ElitSize - spos);

					if (rand() < RAND_MAX)
					{
						Mutate(buffer[ElitIndexer], TargetWord);
					}
				}
			}
			*/
		}
	}

	namespace Common
	{
		static inline bool BoolFitnessSort(GA_Class x, GA_Class y)
		{
			return (x.Fitness < y.Fitness);
		}

		static inline void FitnessSorting(GA_Vector& population)
		{
			sort(population.begin(), population.end(), BoolFitnessSort);
		}

		static inline void PrintTheBest(GA_Vector& Best)
		{
			std::cout << "Best: " << Best[0].StringOfGa << " (" << std::to_string(Best[0].Fitness) << ")" << std::endl;
		}

		static inline void Swap(GA_Vector*& population, GA_Vector*& buffer)
		{
			GA_Vector *TempV = population;
			population = buffer;
			buffer = TempV;
		}
	}
}

int main()
{
	std::string TargetWord; size_t SizeOfPopulation, CountOfIterations;

	//std::cout << "Your target word: ";
	//std::cin >> TargetWord;
	//TargetWord = 
	//	"Well, Prince, so Genoa and Lucca are now just family estates of the Buonapartes.But I warn you, if you don't tell me that this means war,if you still try to defend the infamies and horrors perpetrated by that Antichrist I really believe he is Antichrist I will have nothing more to do with you and you are no longer my friend, no longer my \'faithful slave,' as you call yourself!But how do you do ?I see I have frightened you sit down and tell me all the news.It was in July, 1805, and the speaker was the well known Anna Pavlovna Scherer, maid of honor and favorite of the Empress Marya Fedorovna.With these words she greeted Prince Vasili Kuragin, a man of high rank and importance, who was the first to arrive at her reception. Anna Pavlovna had had a cough for some days. She was, as she said, suffering from la grippe; grippe being then a new word in St. Petersburg, used only by the elite. All her invitations without exception, written in French, and delivered by a scarlet-liveried footman that morning, ran as follows:If you have nothing better to do, Count(or Prince), and if the prospect of spending an evening with a poor invalid is not too terrible, I shall be very charmed to see you tonight between 7 and 10 Annette Scherer. Heavens!what a virulent attack! replied the prince, not in the least disconcerted by this reception. He had just entered, wearing an embroidered court uniform, knee breeches, and shoes, and had stars on his breast and a serene expression.";

	std::cout << "\nSize of your population: ";
	std::cin >> SizeOfPopulation;

	std::cout << "\nCount of iterations: ";
	std::cin >> CountOfIterations;

	srand(unsigned(time(NULL)));

	GA_Vector pop_alpha, pop_beta;
	GA_Vector* population = &pop_alpha, *buffer = &pop_beta;

	Genetic::General::InitPopulation(*population, *buffer, TargetWord, SizeOfPopulation);

	for (ptrdiff_t Index = 0; Index < CountOfIterations; ++Index)
	{
		Genetic::General::FitnessComputing(*population, TargetWord, SizeOfPopulation);
		Genetic::Common::FitnessSorting(*population);

		//Genetic::Common::PrintTheBest(*population);
		if ((*population)[0].Fitness == 0)
		{
			break;
		}

		if (Index > 0) { Genetic::General::Mutation::Mutate(*population, TargetWord); }

		Genetic::General::Crossover(*population, TargetWord);
	}
	Genetic::Common::PrintTheBest(*population);

	return 0;
}