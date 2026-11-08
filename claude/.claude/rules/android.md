# Android (Kotlin) rules

Read alongside `general.md`. Add new Android rules here.

## Coroutines and cancellation

- Never treat cancellation as an error. Rethrow `CancellationException`; don't let a broad `catch (e: Exception)` swallow it.
- A blocking Android call cancelled through a `CancellationSignal` throws `android.os.OperationCanceledException`, which is not a coroutine `CancellationException`. Map it to cancellation when the coroutine was cancelled.
- Run blocking I/O (ContentResolver, disk, `execute()`) on `Dispatchers.IO`, not the caller's dispatcher.
- Work that must finish when the screen goes away (saving state in `onStop`, a sign-out that has started) runs `NonCancellable` or in an app-level scope; `lifecycleScope` and `viewModelScope` are cancelled right after.
- When a newer load supersedes an older one, cancel the older one so a slow result can't overwrite a newer state.

## Untrusted data and failure states

- A malformed server response must show an error, not crash: catch `SerializationException` (and wrap date/time parse errors into it) where API results reach the UI.
- Every load has a visible error state with a way to retry. Don't leave a screen on a spinner when the call fails.
- On a 401 from the app's own API, clear the session; don't just show an error.

## Secrets and sessions

- No passwords, tokens, or session data in `rememberSaveable` or other saved instance state; it can be written to disk.
- Sessions and tokens live only in the encrypted store. A store or key that can't be decrypted means signed out, not a crash.
- Sign-out clears local state even when the network call fails.
- Never add an auth interceptor to an `OkHttpClient` that also fetches third-party or signed object-storage URLs.

## Permissions and lifecycle

- Re-check runtime permissions every time the app returns to the foreground (`ON_START`); the user may have changed them in Settings.
- A configuration change (rotation) is not a fresh start: don't reload data or reset state on it.

## Tests

- Test the failure paths as well as success: network down, non-2xx, malformed body, permission revoked mid-operation, cancellation.
- Keep `android.*` types (e.g. `android.net.Uri`) out of pure logic so it can be unit-tested on the JVM; JVM tests run against stubs that throw.
