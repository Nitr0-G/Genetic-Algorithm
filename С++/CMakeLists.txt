cmake_minimum_required(VERSION 3.15)
project("GeneticAlgo")

add_executable(${PROJECT_NAME}
  "src/MainFile.cpp")

target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_20)
