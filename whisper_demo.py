# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "requests",
#     "sounddevice",
#     "numpy",
# ]
# ///

import io
import sys
import time

import requests
import sounddevice as sd
import wave


SERVER_URL = "http://127.0.0.1:8081/inference"

SAMPLE_RATE = 16_000
CHANNELS = 1
DTYPE = "int16"


def record_until_space():
    """Record from the default microphone until Enter is pressed."""

    print("\nRecording... Press Enter to stop.")

    chunks = []

    # Use a callback so we can accumulate audio while waiting
    # for the user to press Enter.
    def callback(indata, frames, time_info, status):
        if status:
            print(f"\nAudio status: {status}", file=sys.stderr)
        chunks.append(indata.copy())

    with sd.InputStream(
        samplerate=SAMPLE_RATE,
        channels=CHANNELS,
        dtype=DTYPE,
        callback=callback,
    ):
        input()

    if not chunks:
        return None

    # Combine all recorded chunks into one byte string.
    audio_data = b"".join(chunk.tobytes() for chunk in chunks)

    # Create an in-memory WAV file.
    wav = io.BytesIO()

    with wave.open(wav, "wb") as wf:
        wf.setnchannels(CHANNELS)
        wf.setsampwidth(2)  # int16 = 2 bytes
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(audio_data)

    wav.seek(0)
    return wav


def transcribe(wav):
    print("Sending to Whisper...", end="", flush=True)

    response = requests.post(
        SERVER_URL,
        files={
            "file": ("recording.wav", wav, "audio/wav"),
        },
        timeout=300,
    )

    response.raise_for_status()

    result = response.json()
    text = result.get("text", "").strip()

    print("\r" + " " * 30 + "\r", end="")

    return text


def main():
    print("Whisper live recorder")
    print("---------------------")
    print(f"Server: {SERVER_URL}")
    print(f"Sample rate: {SAMPLE_RATE} Hz")
    print()
    print("Press Enter to start recording.")
    print("Press Enter again to stop.")
    print("Press Ctrl+C to quit.")

    while True:
        try:
            input("\n> ")

            wav = record_until_space()

            if wav is None:
                print("No audio recorded.")
                continue

            try:
                text = transcribe(wav)
                print(f"\n{text if text else '[No speech detected]'}")

            except requests.RequestException as e:
                print(f"\nWhisper server error: {e}")

            except (ValueError, KeyError) as e:
                print(f"\nUnexpected server response: {e}")

        except KeyboardInterrupt:
            print("\n\nGoodbye!")
            break


if __name__ == "__main__":
    main()
