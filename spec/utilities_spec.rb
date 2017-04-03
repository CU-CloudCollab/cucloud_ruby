require 'spec_helper'

describe Cucloud::Utilities do
  let(:data) do
    [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
  end

  describe '#confidence_interval_99' do
    it 'should calculate a 99% confidence interval' do
      stats = data.descriptive_statistics
      confidence_interval = Cucloud::Utilities.confidence_interval_99(
        stats[:mean],
        stats[:standard_deviation],
        stats[:number]
      )

      expect(confidence_interval.map!(&:round)).to eq([30, 80])
    end

    it 'should calculate a 95% confidence interval' do
      stats = data.descriptive_statistics
      confidence_interval = Cucloud::Utilities.confidence_interval_95(
        stats[:mean],
        stats[:standard_deviation],
        stats[:number]
      )

      expect(confidence_interval.map!(&:round)).to eq([36, 74])
    end
  end
end
