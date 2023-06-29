# Genetic-Algorithm
  Implementation of a genetic algorithm with a description

# How to compile
  mkdir bld
  cmake ..
  
# Mini practical article about the creation of a genetic algorithm
  Structure of the genetic algorithm:
  ```
    1)Initpopulation
    
    2)FitnessComputing
    
    3)FitnessSorting
    
    4)Mutation
    
    5)Crossover
  ```
    
  1 - At this stage, we generate the original organisms for subsequent generations.
  
  2 - At this stage, we calculate the fitness level of our organisms for our "virtual" environment
  
  3 - At this stage, we sort the organisms by fitness level (we can also do this by other methods)
  
  4 - At this stage, the genes of organisms mutate in accordance with the "rules" of mutation, there are various metaheuristic algorithms for mutation.
  
  5 - At this stage, our organisms carry out biological recombination in accordance with the type of organism, for example, haploid type or diploid type
  
  
  6 - We repeat steps 2 to 5 in accordance with the requirements of the fitness level, i.e. when the fitness level reaches the desired one, then we exit our cycle (verification is usually carried out between 3 and 4 points)
