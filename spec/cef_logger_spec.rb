require 'cef_logger'

class TestLogger
  class << self
    attr_reader :output

    def info(value)
      @output = value
    end
  end
end

describe CefLogger do
  subject { logger.output }

  let(:logger) { TestLogger }

  before do
    allow(Syslog::Logger).to receive(:new).and_return(logger)
    allow(SecureRandom).to receive(:uuid).and_return('id')

    CefLogger.version = '1.0.0'
    CefLogger.product = 'Test'
    CefLogger.vendor = 'Test'
    CefLogger.facility = 10
    CefLogger.filtered_keys = %i[a b]
  end

  it 'filters out given keys' do
    CefLogger.log(name: 'Test|Event', data: { a: 'a' })

    expect(subject).to eq('CEF:0|Test|Test|1.0.0|id|Test\|Event|6|')
  end

  it 'escapes pipes in the header' do
    CefLogger.log(name: 'Test|Event')

    expect(subject).to eq('CEF:0|Test|Test|1.0.0|id|Test\|Event|6|')
  end

  it 'escapes backslashes in extension values' do
    CefLogger.log(name: 'Event', data: { test: '\\a' })

    expect(subject).to eq('CEF:0|Test|Test|1.0.0|id|Event|6|test=\\\\a')
  end

  it 'escapes equal sign in extension values' do
    CefLogger.log(name: 'Event', data: { test: '=a' })

    expect(subject).to eq('CEF:0|Test|Test|1.0.0|id|Event|6|test=\\=a')
  end

  it 'escapes new lines (\n) in extension values' do
    CefLogger.log(name: 'Event', data: { test: "\n" })

    expect(subject).to eq('CEF:0|Test|Test|1.0.0|id|Event|6|test=\n')
  end

  it 'escapes new lines (\r) in extension values' do
    CefLogger.log(name: 'Event', data: { test: "\r" })

    expect(subject).to eq('CEF:0|Test|Test|1.0.0|id|Event|6|test=\r')
  end

  it 'raises for non hash data' do
    expect do
      CefLogger.log(name: 'Event', data: '')
    end.to raise_error("Can't compile non-hashes as extensions for CEF logging!")
  end
end
