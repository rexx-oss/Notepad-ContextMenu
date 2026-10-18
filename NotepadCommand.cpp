#include <windows.h>
#include <shobjidl_core.h>
#include <shlwapi.h>
#include <shellapi.h>

#pragma comment(lib, "shlwapi.lib")
#pragma comment(lib, "shell32.lib")
#pragma comment(lib, "ole32.lib")

#pragma comment(linker, "/export:DllGetClassObject")
#pragma comment(linker, "/export:DllCanUnloadNow")

// CLSID: {CA735A42-3B76-4C41-8B3B-8C4828114002}
static const CLSID CLSID_NotepadCommand = 
    { 0xca735a42, 0x3b76, 0x4c41, { 0x8b, 0x3b, 0x8c, 0x48, 0x28, 0x11, 0x40, 0x02 } };

class NotepadCommand : public IExplorerCommand, public IObjectWithSelection
{
    LONG m_cRef = 1;
    IShellItemArray* m_pSelection = nullptr;

public:
    ~NotepadCommand() {
        if (m_pSelection) { m_pSelection->Release(); m_pSelection = nullptr; }
    }

    IFACEMETHODIMP QueryInterface(REFIID riid, void** ppv) override {
        static const QITAB qit[] = {
            QITABENT(NotepadCommand, IExplorerCommand),
            QITABENT(NotepadCommand, IObjectWithSelection),
            { 0 },
        };
        return QISearch(this, qit, riid, ppv);
    }
    IFACEMETHODIMP_(ULONG) AddRef() override { return InterlockedIncrement(&m_cRef); }
    IFACEMETHODIMP_(ULONG) Release() override {
        LONG cRef = InterlockedDecrement(&m_cRef);
        if (cRef == 0) delete this;
        return cRef;
    }

    IFACEMETHODIMP SetSelection(IShellItemArray* psia) override {
        if (m_pSelection) { m_pSelection->Release(); m_pSelection = nullptr; }
        if (psia) { m_pSelection = psia; m_pSelection->AddRef(); }
        return S_OK;
    }
    IFACEMETHODIMP GetSelection(REFIID riid, void** ppv) override {
        if (!ppv) return E_POINTER;
        *ppv = nullptr;
        return m_pSelection ? m_pSelection->QueryInterface(riid, ppv) : E_NOINTERFACE;
    }

    IFACEMETHODIMP GetTitle(IShellItemArray*, PWSTR* ppszName) override { return SHStrDupW(L"Notepad", ppszName); }
    IFACEMETHODIMP GetIcon(IShellItemArray*, PWSTR* ppszIcon) override { return SHStrDupW(L"C:\\Windows\\System32\\notepad.exe,0", ppszIcon); }
    IFACEMETHODIMP GetToolTip(IShellItemArray*, PWSTR* ppszInfo) override { if (ppszInfo) *ppszInfo = nullptr; return E_NOTIMPL; }
    IFACEMETHODIMP GetCanonicalName(GUID* pguid) override { if (!pguid) return E_POINTER; *pguid = CLSID_NotepadCommand; return S_OK; }
    
    IFACEMETHODIMP GetState(IShellItemArray*, BOOL, EXPCMDSTATE* pCmdState) override {
        if (!pCmdState) return E_POINTER;
        *pCmdState = ECS_ENABLED;
        return S_OK;
    }
    IFACEMETHODIMP GetFlags(EXPCMDFLAGS* pFlags) override { if (!pFlags) return E_POINTER; *pFlags = ECF_DEFAULT; return S_OK; }
    IFACEMETHODIMP EnumSubCommands(IEnumExplorerCommand** ppEnum) override { if (ppEnum) *ppEnum = nullptr; return E_NOTIMPL; }

    IFACEMETHODIMP Invoke(IShellItemArray* psiItemArray, IBindCtx*) override {
        IShellItemArray* items = psiItemArray ? psiItemArray : m_pSelection;
        if (!items) return S_OK;

        DWORD count = 0;
        items->GetCount(&count);
        for (DWORD i = 0; i < count; ++i) {
            IShellItem* item = nullptr;
            if (SUCCEEDED(items->GetItemAt(i, &item))) {
                PWSTR filePath = nullptr;
                if (SUCCEEDED(item->GetDisplayName(SIGDN_FILESYSPATH, &filePath))) {
                    ShellExecuteW(nullptr, L"open", L"C:\\Windows\\System32\\notepad.exe", filePath, nullptr, SW_SHOWNORMAL);
                    CoTaskMemFree(filePath);
                }
                item->Release();
            }
        }
        return S_OK;
    }
};

class ClassFactory : public IClassFactory {
    LONG m_cRef = 1;
public:
    IFACEMETHODIMP QueryInterface(REFIID riid, void** ppv) override {
        if (!ppv) return E_POINTER;
        if (riid == IID_IUnknown || riid == IID_IClassFactory) {
            *ppv = static_cast<IClassFactory*>(this);
            AddRef();
            return S_OK;
        }
        *ppv = nullptr;
        return E_NOINTERFACE;
    }
    IFACEMETHODIMP_(ULONG) AddRef() override { return InterlockedIncrement(&m_cRef); }
    IFACEMETHODIMP_(ULONG) Release() override {
        LONG cRef = InterlockedDecrement(&m_cRef);
        if (cRef == 0) delete this;
        return cRef;
    }
    IFACEMETHODIMP CreateInstance(IUnknown* pUnkOuter, REFIID riid, void** ppv) override {
        if (!ppv) return E_POINTER;
        *ppv = nullptr;
        if (pUnkOuter) return CLASS_E_NOAGGREGATION;

        NotepadCommand* pCmd = new NotepadCommand();
        HRESULT hr = pCmd->QueryInterface(riid, ppv);
        pCmd->Release();
        return hr;
    }
    IFACEMETHODIMP LockServer(BOOL) override { return S_OK; }
};

STDAPI DllGetClassObject(REFCLSID rclsid, REFIID riid, void** ppv) {
    if (!ppv) return E_POINTER;
    *ppv = nullptr;

    if (rclsid == CLSID_NotepadCommand) {
        ClassFactory* pFactory = new ClassFactory();
        HRESULT hr = pFactory->QueryInterface(riid, ppv);
        pFactory->Release();
        return hr;
    }

    return CLASS_E_CLASSNOTAVAILABLE;
}

STDAPI DllCanUnloadNow() {
    return S_OK;
}
