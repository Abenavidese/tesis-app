@app.post("/evaluate")
async def evaluate_proxy(request: EvaluacionRequest):
    """
    Proxy para /evaluate - Evalúa respuesta y envía señal al ESP32 y a la pantalla Nextion

    ESP32:
      'b' si es correcta
      'm' si es incorrecta

    Nextion:
      page2 = ganaste
      page3 = perdiste
    """
    print(f"\n🔍 GATEWAY /evaluate")
    print(f"   Modelo: {request.texto_modelo[:50]}...")
    print(f"   Niño: {request.texto_nino[:50]}...")

    try:
        # Enviar al servidor ML para evaluación
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(
                f"{MODEL_SERVER_URL}/evaluate",
                json={
                    "texto_modelo": request.texto_modelo,
                    "texto_nino": request.texto_nino,
                    "umbral": request.umbral
                }
            )

        # Verificar respuesta
        if response.status_code != 200:
            raise HTTPException(
                status_code=response.status_code,
                detail=f"Error del servidor ML: {response.text}"
            )

        result = response.json()
        es_correcta = result.get("es_correcta", False)

        print(f"   Resultado: {'✅ CORRECTA' if es_correcta else '❌ INCORRECTA'}")

        # Enviar señal al ESP32 según el resultado
        esp32_sent = False
        if es_correcta:
            print("🔵 Enviando señal 'b' (correcto) al ESP32...")
            esp32_sent = await send_to_esp32("b")
        else:
            print("🔵 Enviando señal 'm' (incorrecto) al ESP32...")
            esp32_sent = await send_to_esp32("m")

        # Enviar cambio de página a Nextion
        # page2 = GANASTE, page3 = PERDISTE
        nextion_sent = False
        nextion_cmd = "page page2" if es_correcta else "page page3"

        if es_correcta:
            print("🟣 Enviando a Nextion: page page2 (GANASTE)...")
        else:
            print("🟣 Enviando a Nextion: page page3 (PERDISTE)...")

        nextion_sent = await send_to_nextion(nextion_cmd)

        # Agregar info sobre el ESP32 y Nextion en la respuesta
        result["esp32_signal_sent"] = esp32_sent
        result["esp32_message"] = "b" if es_correcta else "m"

        result["nextion_signal_sent"] = nextion_sent
        result["nextion_command"] = nextion_cmd
        result["nextion_page"] = "page2" if es_correcta else "page3"

        return JSONResponse(
            content=result,
            media_type="application/json; charset=utf-8"
        )

    except httpx.TimeoutException:
        print("❌ GATEWAY - Timeout conectando al servidor ML")
        raise HTTPException(
            status_code=504,
            detail="Timeout conectando al servidor ML"
        )
    except Exception as e:
        print(f"❌ GATEWAY - Error: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error en gateway: {str(e)}"
        )