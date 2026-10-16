# lavora-plugin

Un plugin per Claude Code: `/lavora`, un ciclo di sviluppo a 42 passi per un'app legacy su VM
di sviluppo parallele (un clone per task, un branch per clone), con ClickUp come tracker. Le
altre 14 skill sono i passi della catena, pensati anche per essere lanciati da soli.

Nato dentro un progetto reale, poi ripulito per essere pubblicato: ogni indirizzo, host, id di
ClickUp e nome di persona che compariva nelle skill originali è stato tolto e sostituito da un
segnaposto `${COSÌ}`. **Questo repo non gira finché non lo configuri** — vedi
[Configurazione](#configurazione).

## Cosa fa `/lavora`

Per una task già scritta su ClickUp, in ordine, senza fermarsi a chiedere tra un passo e
l'altro:

1. apre l'ambiente di sviluppo e carica le regole del progetto;
2. legge la task e ne ricava gli obiettivi, in parole da utente;
3. controlla se qualche obiettivo è **già** realizzato — da un'altra task già mergiata, o da un
   branch ancora aperto in parallelo — prima di scrivere una riga;
4. sviluppa quello che manca, rispettando lo standard di codice del progetto;
5. rilegge la task da capo (non il proprio riassunto) per trovare le sviste del primo giro;
6. alterna code-review e correzioni finché il diff è pulito;
7. fa un giro da operatore cercando bug, non solo verificando che "non sia rotto";
8. prova dal vivo ogni obiettivo e dà un verdetto sì/no, misurato quando è quantitativo;
9. chiude con un quadro di ciò che resta aperto — mai un comando suggerito di propria
   iniziativa.

## Le skill

| skill | cosa fa |
|---|---|
| `lavora` | l'orchestratore: lancia le altre 14 nell'ordine giusto, salta i passi senza lavoro, tiene l'avanzamento per poter riprendere |
| `leggi-task` | legge la task ClickUp del branch e ne ricava l'elenco obiettivi, in parole da utente |
| `valuta-pendenze` | cerca per contenuto e per codice — non per titolo — se un obiettivo è già realizzato altrove |
| `sviluppa` | valida ogni obiettivo dal vivo, legge cosa c'è già nel worktree, scrive quello che manca |
| `rileggi-task` | rilegge task e commenti da capo, a raggio più largo, per trovare le sviste del primo giro |
| `applica-standard` | mette il codice appena scritto in regola con lo standard del progetto |
| `test-operatore` | cerca bug provando ogni superficie come un operatore, con casi limite e sequenze sbagliate |
| `testa` | prova dal vivo ogni obiettivo e dà un elenco coperto sì/no, misurando il quantitativo |
| `obiettivi` | rilegge l'ultimo elenco obiettivi e il suo stato, senza rifare il lavoro |
| `pendenze` | riepiloga le decisioni ancora aperte e le voci di checklist non spuntate |
| `aggiorna-task` | aggiorna la card ClickUp: segnalazioni, un commento per punto lavorato, allegati prima/dopo |
| `commita` | fa il commit locale delle modifiche, con il formato di messaggio del progetto |
| `apri-dev1` / `apri-dev2` | apre il browser integrato, autenticato, sullo slot giusto di una delle due VM |
| `cambia-utente` | cambia l'utente di lavoro nel gestionale aperto, verificando che il cambio abbia effetto |

Ogni skill ha una sua descrizione (il campo `description` in cima al `SKILL.md`) pensata per
l'innesco automatico da parte di Claude: leggile per il dettaglio di quando ciascuna scatta.

## Configurazione

1. **Copia `.env.example` in `.env`** e riempi ogni valore: indirizzi delle tue VM, workspace e
   custom field di ClickUp, il tuo account e quello dei colleghi. Ogni variabile ha un commento
   che spiega cosa rappresenta nell'app originale e dove la ritrovi nella tua.
2. **Le skill sono testo, non script**: un agente non legge `.env` da sé. All'inizio della
   sessione, o prima di lanciare `/lavora`, incolla il contenuto di `.env` in chat (o dì
   all'agente di leggerlo) così i segnaposto si risolvono per tutta la sessione. In alternativa,
   sostituisci i valori una volta sola dentro i file `SKILL.md`, con un cerca-e-sostituisci.
3. **Scrivi il `CLAUDE.md` del tuo progetto.** Le skill citano continuamente «il `CLAUDE.md` del
   progetto» per la REGOLA ZERO (mai suggerire i comandi di workflow), la mappa slot↔branch, le
   regole di quoting della shell e i fatti dell'ambiente di sviluppo (es. dove vanno le mail
   inviate da dev). È il contratto su cui queste skill sono scritte: senza, citano una sezione
   che non esiste. Non è incluso qui perché è specifico di ogni progetto — vedi
   [`templates/PROJECT-CLAUDE.md.example`](templates/PROJECT-CLAUDE.md.example) per lo
   scheletro minimo, da completare con le regole vere del tuo codebase.
4. **Adatta ciò che non è portabile.** Due pezzi sono infrastruttura molto specifica
   dell'ambiente originale, descritta nelle skill ma non riprodotta qui:
   - `apri-dev1`/`apri-dev2` presuppongono un proxy locale (tipo Caddy) che porta il browser su
     host `*.localhost` e uno script server-side che fa login senza form né OTP, riservato a un
     account di test. Se non hai un meccanismo equivalente, costruiscine uno sul modello
     descritto, o salta queste due skill e fai il login a mano prima di lanciare le altre.
   - `valuta-pendenze` include uno script di supporto,
     [`skills/valuta-pendenze/branch-in-volo.sh`](plugins/lavora/skills/valuta-pendenze/branch-in-volo.sh),
     che non contiene nulla di specifico del progetto originale: gira così com'è su qualunque
     repo git con un ramo stabile (`origin/retepostale` nell'originale — se il tuo si chiama
     diversamente, cambia quel riferimento nelle skill `valuta-pendenze`, `sviluppa` e
     `rileggi-task`).
5. **Se hai una sola VM di sviluppo**, riempi solo le variabili `DEV1_*`/`DB_IP` e togli dalla
   catena `/lavora` e dalle altre skill i riferimenti a `apri-dev2`/`DEV2_*`.

## Installazione come plugin

```
/plugin marketplace add <percorso-o-url-di-questo-repo>
/plugin install lavora
```

Oppure, per provare prima di pubblicare, cartella e `--plugin-dir` locali.

## Cosa non è incluso

Il connettore ClickUp (MCP) con cui le skill parlano: va configurato a parte, con le tue
credenziali. Le skill assumono i suoi strumenti già autenticati e non chiedono mai una password
o un OTP, salvo l'unica eccezione dell'account di test descritta in `apri-dev1`/`apri-dev2`.
