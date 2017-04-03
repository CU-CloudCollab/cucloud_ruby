module Cucloud
  # Utilities class - for basice shared utilities
  class Utilities
    # Z Score to calculate 99% confidence interval
    Z_SCORE_99 = 2.576
    # Z Score to calculate 99% confidence interval
    Z_SCORE_96 = 1.96

    # Calculate 99% confidence interval
    # @param mean [Float] sample mean
    # @param stdev [Float] sample standard deviation
    # @param sample_size [Integer] sample size
    # @return [Array] Two element array representing the computed confidence interval
    def self.confidence_interval_99(mean, stdev, sample_size)
      confidence_interval(mean, stdev, sample_size, Z_SCORE_99)
    end

    # Calculate 95% confidence interval
    # @param mean [Float] sample mean
    # @param stdev [Float] sample standard deviation
    # @param sample_size [Integer] sample size
    # @return [Array] Two element array representing the computed confidence interval
    def self.confidence_interval_95(mean, stdev, sample_size)
      confidence_interval(mean, stdev, sample_size, Z_SCORE_96)
    end

    private_class_method

    # Calculate confidence interval for given zscore
    # @param mean [Float] sample mean
    # @param stdev [Float] sample standard deviation
    # @param sample_size [Integer] sample size
    # @return [Array] Two element array representing the computed confidence interval
    def self.confidence_interval(mean, stdev, sample_size, zscore)
      delta = zscore * stdev / Math.sqrt(sample_size - 1)
      [mean - delta, mean + delta]
    end
  end
end
